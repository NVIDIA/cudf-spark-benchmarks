WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY l.l_shipmode ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, l.l_shipmode
), HighRevenueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.total_revenue,
        CASE 
            WHEN ro.rank <= 5 THEN 'TOP 5'
            ELSE 'OTHER'
        END AS revenue_category
    FROM 
        RankedOrders ro
), SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS number_of_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
)

SELECT 
    c.c_custkey,
    c.c_name,
    c.c_acctbal,
    COALESCE(hro.total_revenue, 0) AS previous_order_revenue,
    ss.total_supply_cost,
    ss.number_of_parts
FROM 
    customer c
LEFT JOIN 
    HighRevenueOrders hro ON c.c_custkey = hro.o_orderkey
JOIN 
    SupplierSummary ss ON ss.s_suppkey = (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
        WHERE ps.ps_partkey = (SELECT p.p_partkey FROM part p WHERE p.p_name LIKE '%widget%')
        LIMIT 1
    )
WHERE 
    c.c_acctbal > (
        SELECT AVG(c2.c_acctbal) 
        FROM customer c2 
        WHERE c2.c_nationkey = c.c_nationkey
    )
ORDER BY 
    total_supply_cost DESC
LIMIT 10;
