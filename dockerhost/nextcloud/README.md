To enable Redis caching and file locking, in ${VOLUMEDIR}/nextcloud/html/config/config.php

1. Remove:

//  'memcache.local' => '\\OC\\Memcache\\APCu',

2. Add:

  // ✅ Add Redis caching + file locking
  'memcache.local' => '\\OC\\Memcache\\Redis',
  'memcache.locking' => '\\OC\\Memcache\\Redis',
  'redis' => array (
    'host' => 'NextCloudRedis',
    'port' => 6379,
  ),
