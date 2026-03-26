# Expo & React Native — Forge Skill

## Overview

Our mobile app uses Expo (managed workflow) with React Native and TypeScript. Mobile development has unique constraints around performance, navigation, security, and platform differences.

## Project Structure

```
mobile/
  app/                    # Expo Router (file-based routing)
    (tabs)/
      index.tsx
      profile.tsx
      _layout.tsx
    (auth)/
      login.tsx
      register.tsx
      _layout.tsx
    _layout.tsx           # Root layout
  components/
    ui/                   # Reusable UI components
    features/             # Feature-specific components
  hooks/
    useAuth.ts
    useSupabase.ts
  lib/
    supabase.ts
    storage.ts
  constants/
    Colors.ts
    Layout.ts
  assets/
    images/
    fonts/
  app.json                # Expo config
  eas.json                # EAS Build config
```

## Navigation — Expo Router

### File-Based Routing

```typescript
// app/_layout.tsx — Root layout with auth guard
export default function RootLayout() {
  const { session, isLoading } = useAuth();

  if (isLoading) return <SplashScreen />;

  return (
    <Stack>
      {session ? (
        <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
      ) : (
        <Stack.Screen name="(auth)" options={{ headerShown: false }} />
      )}
    </Stack>
  );
}
```

### Navigation Patterns

- Use `<Link>` for declarative navigation
- Use `router.push()` / `router.replace()` for programmatic navigation
- Use `router.replace()` after auth (prevent back to login)
- Use typed routes when possible

### Anti-Patterns

- Don't mix Expo Router with React Navigation directly
- Don't nest navigators unnecessarily
- Don't use deep linking without validation

## Secure Storage

### Sensitive Data Storage

```typescript
import * as SecureStore from 'expo-secure-store';

// GOOD — tokens in secure storage
async function saveToken(token: string) {
  await SecureStore.setItemAsync('auth_token', token);
}

async function getToken() {
  return await SecureStore.getItemAsync('auth_token');
}

// BAD — tokens in AsyncStorage (not encrypted)
import AsyncStorage from '@react-native-async-storage/async-storage';
await AsyncStorage.setItem('auth_token', token); // NOT SECURE
```

### Storage Decision Guide

| Data Type | Storage |
|-----------|---------|
| Auth tokens, secrets | `expo-secure-store` |
| User preferences, settings | `AsyncStorage` |
| Cached API data | `AsyncStorage` or MMKV |
| Large files, images | File system (`expo-file-system`) |
| Offline-first data | SQLite (`expo-sqlite`) or WatermelonDB |

### Security Checklist

- [ ] Auth tokens stored in SecureStore, not AsyncStorage
- [ ] No sensitive data in app state that persists to disk
- [ ] API keys not hardcoded in mobile app (they can be extracted)
- [ ] Certificate pinning considered for sensitive APIs
- [ ] Biometric auth used for sensitive operations where available
- [ ] Deep link URLs validated before navigation
- [ ] No sensitive data in console.log (strip in production)

## Performance

### Lists

```typescript
// BAD — ScrollView with map for dynamic lists
<ScrollView>
  {items.map(item => <ItemCard key={item.id} {...item} />)}
</ScrollView>

// GOOD — FlatList with optimization props
<FlatList
  data={items}
  renderItem={({ item }) => <ItemCard {...item} />}
  keyExtractor={(item) => item.id}
  initialNumToRender={10}
  maxToRenderPerBatch={10}
  windowSize={5}
  removeClippedSubviews={true}
  getItemLayout={(data, index) => ({  // If fixed height
    length: ITEM_HEIGHT,
    offset: ITEM_HEIGHT * index,
    index,
  })}
/>

// BETTER — FlashList for best performance
import { FlashList } from '@shopify/flash-list';
<FlashList
  data={items}
  renderItem={({ item }) => <ItemCard {...item} />}
  estimatedItemSize={ITEM_HEIGHT}
/>
```

### Animations

```typescript
// BAD — JS-driven animation (runs on JS thread)
const [opacity, setOpacity] = useState(1);
useEffect(() => {
  const interval = setInterval(() => {
    setOpacity(prev => prev === 1 ? 0.5 : 1);
  }, 500);
  return () => clearInterval(interval);
}, []);

// GOOD — native driver animation (runs on UI thread)
import Animated, {
  useAnimatedStyle,
  withSpring,
  useSharedValue,
} from 'react-native-reanimated';

const scale = useSharedValue(1);
const animatedStyle = useAnimatedStyle(() => ({
  transform: [{ scale: withSpring(scale.value) }],
}));
```

### Images

```typescript
// Use expo-image for better performance and caching
import { Image } from 'expo-image';

<Image
  source={{ uri: imageUrl }}
  style={styles.image}
  placeholder={blurhash}
  contentFit="cover"
  transition={200}
/>
```

### Performance Checklist

- [ ] FlatList/FlashList for dynamic lists (never ScrollView + map)
- [ ] Animations use native driver or Reanimated
- [ ] Images use expo-image with caching
- [ ] Heavy operations use InteractionManager.runAfterInteractions
- [ ] Memoization for expensive computations
- [ ] No unnecessary re-renders (check with React DevTools Profiler)
- [ ] Bundle size checked (no unnecessary dependencies)
- [ ] Hermes enabled (default in new Expo projects)

## Platform Differences

### Handling Platform-Specific Code

```typescript
import { Platform } from 'react-native';

// Inline
const styles = {
  shadow: Platform.select({
    ios: {
      shadowColor: '#000',
      shadowOffset: { width: 0, height: 2 },
      shadowOpacity: 0.25,
      shadowRadius: 4,
    },
    android: {
      elevation: 4,
    },
  }),
};

// File-based (preferred for larger differences)
// Component.ios.tsx
// Component.android.tsx
```

### Common Platform Issues

| Issue | iOS | Android |
|-------|-----|---------|
| Shadows | `shadow*` properties | `elevation` |
| Safe areas | Dynamic Island, notch | Navigation bar, status bar |
| Keyboard | Pushes content up | May overlay content |
| Permissions | Asked on first use | Manifest + runtime |
| Font rendering | SF Pro (system) | Roboto (system) |
| StatusBar | Light/dark content | Translucent by default |

### Safe Areas

```typescript
import { SafeAreaView } from 'react-native-safe-area-context';

// ALWAYS wrap screens in SafeAreaView
export default function Screen() {
  return (
    <SafeAreaView style={{ flex: 1 }} edges={['top', 'bottom']}>
      {/* Screen content */}
    </SafeAreaView>
  );
}
```

### Keyboard Handling

```typescript
import { KeyboardAvoidingView, Platform } from 'react-native';

<KeyboardAvoidingView
  behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
  style={{ flex: 1 }}
>
  {/* Form content */}
</KeyboardAvoidingView>
```

## Review Severity

| Issue | Severity |
|-------|----------|
| Auth tokens in AsyncStorage | P0 — BLOCKED |
| Sensitive data in console.log (production) | P1 — High |
| ScrollView + map for long lists | P1 — High |
| Missing SafeAreaView | P1 — High |
| JS-driven animations causing jank | P2 — Medium |
| Missing platform-specific handling | P2 — Medium |
| Missing keyboard avoidance on forms | P2 — Medium |
| Using <Image> instead of expo-image | P3 — Low |
| Missing deep link validation | P1 — High |
