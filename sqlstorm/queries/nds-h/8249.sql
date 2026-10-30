WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        c.c_nationkey, 
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rnk
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        SUM(ps.ps_availqty) AS total_available, 
        AVG(ps.ps_supplycost) AS avg_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
LineItemDetails AS (
    SELECT 
        l.l_orderkey, 
        l.l_partkey, 
        SUM(l.l_quantity) AS total_quantity, 
        SUM(l.l_extendedprice) AS total_revenue,
        MAX(l.l_discount) AS max_discount
    FROM lineitem l
    GROUP BY l.l_orderkey, l.l_partkey
)
SELECT 
    R.o_orderkey,
    R.o_orderdate,
    L.total_quantity,
    L.total_revenue,
    L.max_discount,
    SP.total_available,
    SP.avg_cost
FROM RankedOrders R
JOIN LineItemDetails L ON R.o_orderkey = L.l_orderkey
JOIN SupplierParts SP ON L.l_partkey = SP.ps_partkey
WHERE R.rnk = 1 
  AND R.o_totalprice > 1000
ORDER BY R.o_orderdate DESC, L.total_revenue DESC
LIMIT 100;
