#ifndef PB_MAP_H
#define PB_MAP_H

#include "value.h"

typedef struct {
  Value key;
  Value value;
  uint32_t hash;
  int nextBucket;
  int previousOrder;
  int nextOrder;
  bool occupied;
} MapEntry;

typedef struct {
  int count;
  int capacity;
  int used;
  int bucketCapacity;
  int firstOrder;
  int lastOrder;
  int freeList;
  MapEntry* entries;
  int* buckets;
} Map;

void initMap(Map* map);
void freeMap(Map* map);
void markMap(Map* map);
bool mapKeyIsValid(Value key);
bool mapGet(Map* map, Value key, Value* value);
bool mapSet(Map* map, Value key, Value value, bool* isNewKey);
bool mapDelete(Map* map, Value key);
void mapClear(Map* map);
int mapCount(Map* map);
int mapFirstEntry(Map* map);
int mapNextEntry(Map* map, int entryIndex);
MapEntry* mapEntryAt(Map* map, int entryIndex);

#endif
