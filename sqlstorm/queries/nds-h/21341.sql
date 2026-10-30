
WITH RankedSuppliers AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        s.s_name,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost DESC) AS rank_cost,
        SUM(ps.ps_availqty) OVER (PARTITION BY ps.ps_partkey) AS total_avail_qty
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
),
FrequentCustomers AS (
    SELECT 
        o.o_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM orders o
    WHERE o.o_orderdate BETWEEN DATE '1998-10-01' - INTERVAL '1 year' AND DATE '1998-10-01'
    GROUP BY o.o_custkey
    HAVING COUNT(DISTINCT o.o_orderkey) > 5
)
SELECT 
    p.p_name,
    p.p_brand,
    COALESCE(rn.rn_max_price, 0) AS max_price,
    rc.total_avail_qty,
    fc.order_count,
    (SELECT COUNT(*) FROM region) AS total_regions,
    CASE 
        WHEN fc.order_count IS NULL THEN 'No Orders'
        WHEN fc.order_count > 10 THEN 'Frequent Buyer'
        ELSE 'Occasional Buyer'
    END AS buyer_category
FROM part p
LEFT JOIN (
    SELECT 
        ps.ps_partkey,
        MAX(ps.ps_supplycost) AS rn_max_price
    FROM partsupp ps
    GROUP BY ps.ps_partkey
) rn ON p.p_partkey = rn.ps_partkey
LEFT JOIN RankedSuppliers rs ON p.p_partkey = rs.ps_partkey AND rs.rank_cost = 1
LEFT JOIN FrequentCustomers fc ON rs.ps_suppkey = fc.o_custkey
LEFT JOIN (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty
    FROM partsupp ps
    GROUP BY ps.ps_partkey
) rc ON p.p_partkey = rc.ps_partkey
WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) 
                          FROM part p2 
                          WHERE p2.p_size BETWEEN 5 AND 25
                          AND p2.p_type LIKE '%wood%')
OR p.p_type IS NULL
ORDER BY p.p_name ASC, rc.total_avail_qty DESC
LIMIT 100;
