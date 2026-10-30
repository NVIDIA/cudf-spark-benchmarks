
WITH TotalSales AS (
    SELECT l.l_partkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    WHERE l.l_shipdate >= DATE '1997-01-01' 
      AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY l.l_partkey
),
SupplierDetails AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_nationkey, 
           SUM(ps.ps_availqty) AS total_avail_qty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
RankedSales AS (
    SELECT t.l_partkey, 
           t.total_revenue,
           RANK() OVER (ORDER BY t.total_revenue DESC) AS revenue_rank
    FROM TotalSales t
),
PartInfo AS (
    SELECT p.p_partkey,
           p.p_name,
           p.p_brand,
           p.p_retailprice,
           COALESCE(r.n_name, 'Unknown') AS region_name,
           COALESCE(sd.total_avail_qty, 0) AS total_available_quantity
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    LEFT JOIN nation r ON s.s_nationkey = r.n_nationkey
    LEFT JOIN SupplierDetails sd ON s.s_suppkey = sd.s_suppkey
)
SELECT pi.p_partkey,
       pi.p_name,
       pi.p_brand,
       pi.p_retailprice,
       pi.total_available_quantity,
       rs.total_revenue,
       rs.revenue_rank
FROM PartInfo pi
JOIN RankedSales rs ON pi.p_partkey = rs.l_partkey
WHERE pi.total_available_quantity > 50
  AND (rs.revenue_rank <= 10 OR pi.region_name = 'Europe')
ORDER BY rs.total_revenue DESC, pi.p_name ASC;
