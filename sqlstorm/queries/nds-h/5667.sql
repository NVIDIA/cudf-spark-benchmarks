WITH RankedOrders AS (
  SELECT 
    o.o_orderkey,
    c.c_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
  FROM 
    orders o
  JOIN 
    customer c ON o.o_custkey = c.c_custkey
  JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
  GROUP BY 
    o.o_orderkey, c.c_name, c.c_nationkey
)
SELECT 
  r.r_name AS region,
  n.n_name AS nation,
  COUNT(DISTINCT ro.o_orderkey) AS order_count,
  SUM(ro.total_revenue) AS total_revenue
FROM 
  RankedOrders ro
JOIN 
  supplier s ON ro.o_orderkey = s.s_suppkey
JOIN 
  partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
  part p ON ps.ps_partkey = p.p_partkey
JOIN 
  nation n ON s.s_nationkey = n.n_nationkey
JOIN 
  region r ON n.n_regionkey = r.r_regionkey
WHERE 
  ro.rank <= 5
GROUP BY 
  r.r_name, n.n_name
HAVING 
  SUM(ro.total_revenue) > 1000000
ORDER BY 
  total_revenue DESC;
