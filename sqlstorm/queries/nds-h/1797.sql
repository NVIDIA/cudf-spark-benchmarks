WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS price_rank,
        c.c_name,
        c.c_nationkey
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
),
HighValueOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.o_totalprice,
        r.c_name,
        n.n_name AS nation_name,
        r.price_rank
    FROM 
        RankedOrders r
    LEFT JOIN 
        nation n ON r.c_nationkey = n.n_nationkey
    WHERE 
        r.price_rank <= 10
),
EstimatedCost AS (
    SELECT 
        ps.ps_partkey,
        AVG(ps.ps_supplycost) * SUM(l.l_quantity) AS estimated_cost
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_shipdate BETWEEN '1997-07-01' AND '1997-12-31'
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    h.o_orderkey,
    h.o_orderdate,
    h.o_totalprice,
    h.c_name,
    h.nation_name,
    ec.estimated_cost,
    CASE 
        WHEN ec.estimated_cost IS NULL THEN 'No Estimate'
        ELSE 'Estimate Available'
    END AS estimate_status
FROM 
    HighValueOrders h
LEFT JOIN 
    EstimatedCost ec ON h.o_orderkey = ec.ps_partkey
ORDER BY 
    h.o_orderdate DESC,
    h.o_totalprice DESC;