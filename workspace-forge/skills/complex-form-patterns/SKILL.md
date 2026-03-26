---
name: complex-form-patterns
description: React Hook Form + Zod patterns, multi-step forms, optimistic submission, file uploads in forms, and accessible form architecture.
---

# Complex Form Patterns

## React Hook Form + Zod (Production Pattern)

```tsx
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'

const schema = z.object({
  title: z.string().min(3, 'Title must be at least 3 characters').max(100),
  category: z.enum(['code', 'research', 'creative', 'design', 'strategy']),
  timeLimit: z.number().min(900).max(172800),
  weightClass: z.enum(['frontier', 'contender', 'scrapper', 'underdog', 'open']),
  description: z.string().min(20).max(5000),
})

type FormData = z.infer<typeof schema>

function CreateChallengeForm() {
  const { register, handleSubmit, formState: { errors, isSubmitting } } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: { category: 'code', timeLimit: 1800, weightClass: 'open' },
  })

  const onSubmit = async (data: FormData) => {
    const result = await createChallenge(data)
    if (result.error) toast.error(result.error)
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <div>
        <label htmlFor="title">Title</label>
        <input id="title" {...register('title')} aria-describedby="title-error" />
        {errors.title && <p id="title-error" className="text-red-500 text-sm">{errors.title.message}</p>}
      </div>
      {/* ... other fields */}
      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? 'Creating...' : 'Create Challenge'}
      </button>
    </form>
  )
}
```

## Multi-Step Forms

```tsx
function OnboardingWizard() {
  const [step, setStep] = useState(1)
  const [data, setData] = useState<Partial<OnboardingData>>({})

  // Persist draft to localStorage on each step
  useEffect(() => {
    localStorage.setItem('onboarding_draft', JSON.stringify(data))
  }, [data])

  // Restore on mount
  useEffect(() => {
    const saved = localStorage.getItem('onboarding_draft')
    if (saved) setData(JSON.parse(saved))
  }, [])

  function handleStepComplete(stepData: Partial<OnboardingData>) {
    const merged = { ...data, ...stepData }
    setData(merged)
    if (step < TOTAL_STEPS) setStep(step + 1)
    else submitOnboarding(merged as OnboardingData)
  }

  return (
    <div>
      <ProgressBar current={step} total={TOTAL_STEPS} />
      {step === 1 && <AccountStep data={data} onComplete={handleStepComplete} />}
      {step === 2 && <AgentStep data={data} onComplete={handleStepComplete} />}
      {step === 3 && <GatewayStep data={data} onComplete={handleStepComplete} />}
      {step > 1 && <button onClick={() => setStep(step - 1)}>Back</button>}
    </div>
  )
}
```

**Rules:**
- Validate each step independently before allowing progression
- Allow back navigation without losing data
- Submit only on final step
- Each step has its own Zod schema

## Optimistic Submission with Server Actions

```tsx
import { useOptimistic } from 'react'

function VoteButton({ entryId, votes }: { entryId: string; votes: number }) {
  const [optimisticVotes, addVote] = useOptimistic(votes, (s) => s + 1)

  async function handleVote() {
    addVote(null)                    // Instantly show +1
    await submitVote(entryId)        // Server Action (auto-reverts on failure)
  }

  return <button onClick={handleVote}>⬆ {optimisticVotes}</button>
}
```

## Accessible Forms (Critical)

```tsx
// Every input needs:
<label htmlFor="email">Email</label>
<input 
  id="email" 
  type="email"
  aria-required="true"
  aria-invalid={!!errors.email}
  aria-describedby={errors.email ? 'email-error' : undefined}
  {...register('email')} 
/>
{errors.email && (
  <p id="email-error" role="alert" className="text-red-500 text-sm">
    {errors.email.message}
  </p>
)}

// On failed submission: focus first error field
useEffect(() => {
  const firstError = Object.keys(errors)[0]
  if (firstError) document.getElementById(firstError)?.focus()
}, [errors])
```

## File Upload in Forms

```tsx
function FileUpload({ onUploaded }: { onUploaded: (url: string) => void }) {
  const [progress, setProgress] = useState(0)
  
  async function handleFile(file: File) {
    // Client-side validation (UX)
    if (file.size > 10 * 1024 * 1024) return toast.error('Max 10MB')
    if (!['image/jpeg', 'image/png'].includes(file.type)) return toast.error('JPG/PNG only')
    
    // Get presigned URL
    const { signedUrl, path } = await getUploadUrl(file.name, file.type)
    
    // Upload with progress
    const xhr = new XMLHttpRequest()
    xhr.upload.onprogress = (e) => setProgress(Math.round(e.loaded / e.total * 100))
    xhr.onload = () => onUploaded(path)
    xhr.open('PUT', signedUrl)
    xhr.setRequestHeader('Content-Type', file.type)
    xhr.send(file)
  }
  
  return (
    <div>
      <input type="file" accept="image/*" onChange={e => handleFile(e.target.files![0])} />
      {progress > 0 && progress < 100 && <progress value={progress} max={100} />}
    </div>
  )
}
```

## Sources
- react-hook-form documentation (resolver, field arrays)
- Zod documentation (schema composition)
- WCAG 2.1 form accessibility guidelines
- Next.js Server Actions documentation

## Changelog
- 2026-03-21: Initial skill — complex form patterns
