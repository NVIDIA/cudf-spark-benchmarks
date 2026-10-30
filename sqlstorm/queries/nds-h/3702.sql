WITH SupplierPricing AS (
    SELECT
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        AVG(ps.ps_supplycost) AS avg_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey
),
RevenueAnalysis AS (
    SELECT
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        ROW_NUMBER() OVER (PARTITION BY l.l_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM lineitem l
    GROUP BY l.l_partkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        r.r_name,
        COALESCE(sp.total_cost, 0) AS total_cost
    FROM supplier s
    LEFT JOIN region r ON s.s_nationkey = r.r_regionkey
    LEFT JOIN SupplierPricing sp ON s.s_suppkey = sp.ps_partkey
    ORDER BY total_cost DESC
    LIMIT 10
)
SELECT
    TOP.s_suppkey,
    TOP.s_name,
    C.c_custkey,
    C.total_spent,
    C.order_count,
    RA.revenue,
    RA.revenue_rank
FROM TopSuppliers TOP
LEFT JOIN CustomerOrders C ON C.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_address LIKE '%Street%' LIMIT 1)
LEFT JOIN RevenueAnalysis RA ON RA.l_partkey = TOP.s_suppkey
WHERE (C.total_spent IS NOT NULL OR RA.revenue IS NOT NULL)
AND (TOP.total_cost > 50000 OR C.order_count > 5)
ORDER BY RA.revenue_rank ASC, TOP.total_cost DESC;
