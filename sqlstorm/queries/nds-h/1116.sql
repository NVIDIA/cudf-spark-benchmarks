WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= '1996-01-01' AND o.o_orderstatus = 'O'
),
TopEntities AS (
    SELECT 
        r.r_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        r.r_name
)
SELECT 
    r.r_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    COALESCE(SUM(o.o_totalprice), 0) AS total_order_value,
    COALESCE(MAX(o.o_totalprice), 0) AS max_order_value,
    AVG(CASE WHEN o.o_totalprice > 1000 THEN o.o_totalprice END) AS avg_high_value_order
FROM 
    RankedOrders o
FULL OUTER JOIN 
    TopEntities r ON r.r_name = 
        CASE 
            WHEN o.o_orderkey IS NOT NULL THEN 'north america' 
            ELSE 'global' 
        END
WHERE 
    o.order_rank <= 10 OR o.order_rank IS NULL
GROUP BY 
    r.r_name
ORDER BY 
    total_order_value DESC, r.r_name;