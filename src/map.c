#include <math.h>
#include <string.h>

#include "headers/map.h"
#include "headers/memory.h"
#include "headers/object.h"

#define MAP_MAX_LOAD 0.75

static uint32_t hashNumber(double number) {
  if (number == 0) number = 0;

  uint64_t bits;
  memcpy(&bits, &number, sizeof(double));
  bits ^= bits >> 33;
  bits *= UINT64_C(0xff51afd7ed558ccd);
  bits ^= bits >> 33;
  bits *= UINT64_C(0xc4ceb9fe1a85ec53);
  bits ^= bits >> 33;
  return (uint32_t)(bits ^ (bits >> 32));
}

static uint32_t mapKeyHash(Value key) {
  switch (key.type) {
    case VAL_NIL:
      return 0x9e3779b9u;
    case VAL_BOOL:
      return AS_BOOL(key) ? 0x85ebca6bu : 0xc2b2ae35u;
    case VAL_NUMBER:
      return hashNumber(AS_NUMBER(key));
    case VAL_OBJ:
      return AS_STRING(key)->hash;
  }

  return 0;
}

static int findEntry(Map* map, Value key, uint32_t hash, int* previous) {
  if (map->bucketCapacity == 0) return -1;

  int bucket = (int)(hash & (uint32_t)(map->bucketCapacity - 1));
  int current = map->buckets[bucket];
  int prior = -1;

  while (current != -1) {
    MapEntry* entry = &map->entries[current];
    if (entry->hash == hash && valuesEqual(entry->key, key)) {
      if (previous != NULL) *previous = prior;
      return current;
    }
    prior = current;
    current = entry->nextBucket;
  }

  if (previous != NULL) *previous = prior;
  return -1;
}

static void adjustBucketCapacity(Map* map, int capacity) {
  int* buckets = ALLOCATE(int, capacity);
  for (int i = 0; i < capacity; i++) {
    buckets[i] = -1;
  }

  for (int i = 0; i < map->used; i++) {
    MapEntry* entry = &map->entries[i];
    if (!entry->occupied) continue;

    int bucket = (int)(entry->hash & (uint32_t)(capacity - 1));
    entry->nextBucket = buckets[bucket];
    buckets[bucket] = i;
  }

  FREE_ARRAY(int, map->buckets, map->bucketCapacity);
  map->buckets = buckets;
  map->bucketCapacity = capacity;
}

static int allocateEntry(Map* map) {
  if (map->freeList != -1) {
    int index = map->freeList;
    map->freeList = map->entries[index].nextBucket;
    return index;
  }

  if (map->used == map->capacity) {
    int oldCapacity = map->capacity;
    map->capacity = GROW_CAPACITY(oldCapacity);
    map->entries = GROW_ARRAY(MapEntry, map->entries, oldCapacity, map->capacity);
  }

  return map->used++;
}

void initMap(Map* map) {
  map->count = 0;
  map->capacity = 0;
  map->used = 0;
  map->bucketCapacity = 0;
  map->firstOrder = -1;
  map->lastOrder = -1;
  map->freeList = -1;
  map->entries = NULL;
  map->buckets = NULL;
}

void freeMap(Map* map) {
  FREE_ARRAY(MapEntry, map->entries, map->capacity);
  FREE_ARRAY(int, map->buckets, map->bucketCapacity);
  initMap(map);
}

bool mapKeyIsValid(Value key) {
  if (IS_NIL(key) || IS_BOOL(key)) return true;
  if (IS_NUMBER(key)) return isfinite(AS_NUMBER(key));
  return IS_STRING(key);
}

bool mapGet(Map* map, Value key, Value* value) {
  if (!mapKeyIsValid(key)) return false;

  int index = findEntry(map, key, mapKeyHash(key), NULL);
  if (index == -1) return false;

  *value = map->entries[index].value;
  return true;
}

bool mapSet(Map* map, Value key, Value value, bool* isNewKey) {
  if (!mapKeyIsValid(key)) return false;

  uint32_t hash = mapKeyHash(key);
  int existing = findEntry(map, key, hash, NULL);
  if (existing != -1) {
    map->entries[existing].value = value;
    if (isNewKey != NULL) *isNewKey = false;
    return true;
  }

  if (map->count + 1 > map->bucketCapacity * MAP_MAX_LOAD) {
    adjustBucketCapacity(map, GROW_CAPACITY(map->bucketCapacity));
  }

  int index = allocateEntry(map);
  MapEntry* entry = &map->entries[index];
  int bucket = (int)(hash & (uint32_t)(map->bucketCapacity - 1));

  entry->key = key;
  entry->value = value;
  entry->hash = hash;
  entry->nextBucket = map->buckets[bucket];
  entry->previousOrder = map->lastOrder;
  entry->nextOrder = -1;
  entry->occupied = true;

  map->buckets[bucket] = index;
  if (map->lastOrder != -1) {
    map->entries[map->lastOrder].nextOrder = index;
  } else {
    map->firstOrder = index;
  }
  map->lastOrder = index;
  map->count++;

  if (isNewKey != NULL) *isNewKey = true;
  return true;
}

bool mapDelete(Map* map, Value key) {
  if (!mapKeyIsValid(key)) return false;

  uint32_t hash = mapKeyHash(key);
  int previousBucket = -1;
  int index = findEntry(map, key, hash, &previousBucket);
  if (index == -1) return false;

  MapEntry* entry = &map->entries[index];
  int bucket = (int)(hash & (uint32_t)(map->bucketCapacity - 1));
  if (previousBucket == -1) {
    map->buckets[bucket] = entry->nextBucket;
  } else {
    map->entries[previousBucket].nextBucket = entry->nextBucket;
  }

  if (entry->previousOrder != -1) {
    map->entries[entry->previousOrder].nextOrder = entry->nextOrder;
  } else {
    map->firstOrder = entry->nextOrder;
  }
  if (entry->nextOrder != -1) {
    map->entries[entry->nextOrder].previousOrder = entry->previousOrder;
  } else {
    map->lastOrder = entry->previousOrder;
  }

  entry->key = NIL_VAL;
  entry->value = NIL_VAL;
  entry->occupied = false;
  entry->nextBucket = map->freeList;
  entry->previousOrder = -1;
  entry->nextOrder = -1;
  map->freeList = index;
  map->count--;
  return true;
}

void mapClear(Map* map) {
  freeMap(map);
}

int mapCount(Map* map) {
  return map->count;
}

int mapFirstEntry(Map* map) {
  return map->firstOrder;
}

int mapNextEntry(Map* map, int entryIndex) {
  return map->entries[entryIndex].nextOrder;
}

MapEntry* mapEntryAt(Map* map, int entryIndex) {
  return &map->entries[entryIndex];
}

void markMap(Map* map) {
  for (int index = map->firstOrder; index != -1; index = map->entries[index].nextOrder) {
    MapEntry* entry = &map->entries[index];
    markValue(entry->key);
    markValue(entry->value);
  }
}
