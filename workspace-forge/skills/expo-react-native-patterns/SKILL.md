---
name: expo-react-native-patterns
description: Expo/React Native patterns for MathMind and Arena mobile — navigation, NativeWind, performance, offline-first, push notifications, App Store deployment, security.
---

# Expo / React Native Patterns

## Review Checklist

1. [ ] `expo-image` used (not `Image` from react-native)
2. [ ] `FlatList` for lists >20 items (not `ScrollView`)
3. [ ] Sensitive data in `expo-secure-store` (not `AsyncStorage`)
4. [ ] `SafeAreaView` or `useSafeAreaInsets()` on every screen
5. [ ] Animations use `react-native-reanimated` (UI thread, 60fps)
6. [ ] Push notification permission requested at appropriate time
7. [ ] Offline state handled gracefully
8. [ ] Deep links tested on both iOS and Android

---

## Platform Differences from Web

| Web | React Native |
|-----|-------------|
| `<div>` | `<View>` |
| `<span>`, `<p>` | `<Text>` (text MUST be in `<Text>`) |
| `<button>` | `<Pressable>` |
| `<img>` | `<Image>` from expo-image |
| CSS classes | `StyleSheet.create()` or NativeWind |
| Flexbox (row default) | Flexbox (column default) |
| `window.localStorage` | `AsyncStorage` (unencrypted) or `expo-secure-store` (encrypted) |
| Media queries | `useWindowDimensions()` |

## Expo Router (File-Based Navigation)

```
app/
├── (tabs)/              # Tab navigator group
│   ├── _layout.tsx      # Tab bar configuration
│   ├── index.tsx        # Home tab
│   ├── challenges.tsx   # Challenges tab
│   └── profile.tsx      # Profile tab
├── challenge/
│   └── [id].tsx         # Dynamic route: /challenge/abc-123
├── modal.tsx            # Presented as modal (presentation: 'modal')
└── _layout.tsx          # Root layout (auth check, providers)
```

```tsx
// Type-safe route params
import { useLocalSearchParams } from 'expo-router'
export default function ChallengeDetail() {
  const { id } = useLocalSearchParams<{ id: string }>()
  // id is typed as string
}
```

## Performance Patterns

### FlatList over ScrollView
```tsx
// ❌ Renders ALL items at once (slow for >20 items)
<ScrollView>
  {items.map(item => <ItemCard key={item.id} item={item} />)}
</ScrollView>

// ✅ Virtualizes — only renders visible items
<FlatList
  data={items}
  keyExtractor={item => item.id}
  renderItem={({ item }) => <ItemCard item={item} />}
  getItemLayout={(_, index) => ({ length: 80, offset: 80 * index, index })}
  // getItemLayout enables instant scroll-to-index
/>
```

### expo-image over Image
```tsx
// ❌ No caching, no blurhash, no transitions
import { Image } from 'react-native'
<Image source={{ uri: avatarUrl }} style={{ width: 48, height: 48 }} />

// ✅ Built-in caching, blurhash placeholder, smooth transitions
import { Image } from 'expo-image'
<Image 
  source={avatarUrl}
  style={{ width: 48, height: 48 }}
  placeholder={blurhash}
  transition={200}
  contentFit="cover"
/>
```

### Reanimated for Animations
```tsx
// ❌ JS thread animation (drops frames during heavy computation)
import { Animated } from 'react-native'

// ✅ UI thread animation (smooth 60fps always)
import Animated, { useSharedValue, useAnimatedStyle, withSpring } from 'react-native-reanimated'

function AnimatedCard() {
  const scale = useSharedValue(1)
  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }]
  }))
  
  return (
    <Pressable onPressIn={() => { scale.value = withSpring(0.95) }}
               onPressOut={() => { scale.value = withSpring(1) }}>
      <Animated.View style={animatedStyle}>
        <Text>Card content</Text>
      </Animated.View>
    </Pressable>
  )
}
```

## Security

### Storage Security
```ts
// ❌ AsyncStorage is UNENCRYPTED — visible to anyone with device access
import AsyncStorage from '@react-native-async-storage/async-storage'
await AsyncStorage.setItem('auth_token', token) // INSECURE

// ✅ expo-secure-store uses iOS Keychain / Android Keystore
import * as SecureStore from 'expo-secure-store'
await SecureStore.setItemAsync('auth_token', token) // ENCRYPTED
```

### What Goes Where
| Data | Storage | Why |
|------|---------|-----|
| Auth tokens | `expo-secure-store` | Encrypted, OS-protected |
| User preferences | `AsyncStorage` | Not sensitive |
| Cached API data | `AsyncStorage` | Not sensitive, needs fast access |
| Problem history (MathMind) | `expo-sqlite` | Structured, offline-queryable |
| Encryption keys | `expo-secure-store` | Maximum protection |

## Offline-First Pattern (MathMind)

```ts
// 1. Try network, fall back to cache
async function getProblems(grade: number) {
  try {
    const online = await NetInfo.fetch()
    if (online.isConnected) {
      const data = await fetchFromSupabase(grade)
      await cacheLocally(grade, data) // update cache
      return data
    }
  } catch {} // network failed
  
  return getCachedProblems(grade) // offline fallback
}

// 2. Queue mutations for sync
async function submitAnswer(answer: Answer) {
  await saveToLocalDb(answer) // always save locally first
  
  const online = await NetInfo.fetch()
  if (online.isConnected) {
    await syncToSupabase(answer)
  } else {
    await addToSyncQueue(answer) // sync when back online
  }
}
```

## App Store Deployment

```bash
# Build for production
eas build --platform ios --profile production

# Submit to App Store
eas submit --platform ios

# OTA update (JS-only changes, no native module changes)
eas update --branch production --message "Fix scoring display"
```

### MathMind-Specific Considerations
- **Kids Category:** requires COPPA compliance, no third-party analytics, no behavioral ads
- **Age rating:** educational content, no user-generated content = likely 4+
- **Login for reviewer:** provide test credentials in App Store Connect

## Sources
- expo/expo documentation
- expo/examples (navigation, auth, notifications)
- nativewind/nativewind (Tailwind compilation)
- React Native performance documentation

## Changelog
- 2026-03-21: Initial skill — Expo/React Native patterns
