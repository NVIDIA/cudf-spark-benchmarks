WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        CTE.cust_rank
    FROM 
        orders o
    JOIN (
        SELECT 
            c.c_custkey,
            RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS cust_rank
        FROM 
            customer c
        WHERE 
            c.c_acctbal IS NOT NULL
    ) CTE ON o.o_custkey = CTE.c_custkey
), TotalLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    WHERE 
        l.l_shipmode = 'MAIL'
    GROUP BY 
        l.l_orderkey
),
FilteredParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_size > 0
    GROUP BY 
        ps.ps_partkey
    HAVING 
        SUM(ps.ps_supplycost) > (SELECT AVG(ps_supplycost) FROM partsupp)
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    COALESCE(t.total_revenue, 0) AS total_revenue,
    p.p_name,
    p.p_retailprice,
    COALESCE(fp.total_supply_cost, 0) AS part_supply_cost,
    RANK() OVER (PARTITION BY r.o_orderkey ORDER BY r.o_orderdate) AS order_rank,
    CASE 
        WHEN r.o_totalprice > 2000 THEN 'High Value'
        ELSE 'Standard'
    END AS order_value_category
FROM 
    RankedOrders r
LEFT JOIN 
    TotalLineItems t ON r.o_orderkey = t.l_orderkey
JOIN 
    lineitem l ON r.o_orderkey = l.l_orderkey
JOIN 
    part p ON l.l_partkey = p.p_partkey
LEFT JOIN 
    FilteredParts fp ON p.p_partkey = fp.ps_partkey
WHERE 
    r.o_orderdate > (cast('1998-10-01' as date) - INTERVAL '1 year') 
    AND (fp.total_supply_cost IS NULL OR fp.total_supply_cost < 5000)
ORDER BY 
    r.o_orderdate DESC, total_revenue DESC;