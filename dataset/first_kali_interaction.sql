-- ============================================================
-- First meaningful interaction with team Kali (10.0.x.30), x=1..12
-- Excludes: external, infra(10.0.242/24), collector(10.0.x.9),
--           Windows noise ports (135,137,138,139,445),
--           noisy Windows host (10.0.x.29)
-- ============================================================

WITH teams AS (
  SELECT
    x AS team_n,
    '10.0.' || x::VARCHAR || '.30' AS kali_ip,
    '10.0.' || x::VARCHAR || '.9'  AS collector_ip,
    '10.0.' || x::VARCHAR || '.29' AS noisy_win_ip
  FROM generate_series(1, 12) AS t(x)
),

cand AS (
  SELECT
    t.team_n,
    t.kali_ip,
    n.ts, n.src, n.dst, n.sport, n.dport, n.proto, n.app, n.bytes, n.pkts,
    CASE WHEN n.src = t.kali_ip THEN n.dst ELSE n.src END AS peer_ip,
    CASE WHEN n.src = t.kali_ip THEN 'outbound_from_kali' ELSE 'inbound_to_kali' END AS direction
  FROM nf n
  JOIN teams t
    ON (n.src = t.kali_ip OR n.dst = t.kali_ip)

  WHERE
    -- internal only (exclude external networks)
    n.src LIKE '10.%'
    AND n.dst LIKE '10.%'

    -- exclude infra subnet
    AND NOT (n.src LIKE '10.0.242.%' OR n.dst LIKE '10.0.242.%')

    -- exclude per-team collector
    AND n.src <> t.collector_ip
    AND n.dst <> t.collector_ip

    -- OPTIONAL (enabled): exclude noisy Windows host .29 in same team subnet
    AND n.src <> t.noisy_win_ip
    AND n.dst <> t.noisy_win_ip
),

in_team_subnet AS (
  SELECT *
  FROM cand
  WHERE
    -- only peers within same team subnet 10.0.x.0/24
    peer_ip LIKE ('10.0.' || team_n::VARCHAR || '.%')
    AND peer_ip <> kali_ip
)

SELECT
  team_n,
  '10.0.' || team_n::VARCHAR || '.0/24' AS subnet,
  kali_ip,
  MIN(ts) AS first_seen,

  -- exact first flow (row with smallest ts)
  arg_min(src, ts)       AS first_src,
  arg_min(dst, ts)       AS first_dst,
  arg_min(sport, ts)     AS first_sport,
  arg_min(dport, ts)     AS first_dport,
  arg_min(proto, ts)     AS first_proto,
  arg_min(app, ts)       AS first_app,
  arg_min(bytes, ts)     AS first_bytes,
  arg_min(pkts, ts)      AS first_pkts,
  arg_min(direction, ts) AS first_direction,
  arg_min(peer_ip, ts)   AS first_peer
FROM in_team_subnet
GROUP BY team_n, kali_ip
ORDER BY first_seen;