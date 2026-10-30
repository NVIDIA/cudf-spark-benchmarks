WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.total_revenue,
        CASE 
            WHEN ro.total_revenue > (SELECT AVG(total_revenue) FROM RankedOrders) THEN 'Above Average'
            ELSE 'Below Average'
        END AS revenue_category
    FROM 
        RankedOrders ro
    WHERE 
        ro.order_rank <= 5
),
SupplierStats AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_suppkey
)
SELECT 
    na.n_name AS nation_name,
    r.r_name AS region_name,
    COALESCE(so.total_revenue, 0) AS total_order_revenue,
    COALESCE(ss.total_supply_cost, 0) AS supplier_cost,
    ss.part_count,
    CASE 
        WHEN ss.total_supply_cost IS NULL THEN 'No Supplies'
        WHEN ss.part_count > 0 THEN 'Supplies Available'
        ELSE 'No Supplies Available'
    END AS supply_status
FROM 
    nation na
LEFT JOIN 
    region r ON na.n_regionkey = r.r_regionkey
LEFT JOIN 
    (SELECT DISTINCT c.c_nationkey, SUM(oo.total_revenue) AS total_revenue
     FROM customer c
     LEFT JOIN TopOrders oo ON c.c_custkey = oo.o_orderkey
     GROUP BY c.c_nationkey) so ON na.n_nationkey = so.c_nationkey
LEFT JOIN 
    (SELECT 
        s.s_nationkey,
        SUM(ss.total_supply_cost) AS total_supply_cost,
        SUM(ss.part_count) AS part_count
     FROM 
        supplier s
     JOIN 
        SupplierStats ss ON s.s_suppkey = ss.ps_suppkey
     GROUP BY 
        s.s_nationkey) ss ON na.n_nationkey = ss.s_nationkey
WHERE 
    na.n_name IS NOT NULL
ORDER BY 
    nation_name, region_name;
