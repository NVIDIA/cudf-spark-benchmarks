
WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
),
supplier_costs AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
lineitem_summary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_income,
        COUNT(CASE WHEN l.l_returnflag = 'R' THEN 1 END) AS return_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    r.total_income,
    r.return_count,
    COALESCE(sc.total_supply_cost, 0) AS supplier_cost
FROM 
    ranked_orders o
LEFT JOIN 
    lineitem_summary r ON o.o_orderkey = r.l_orderkey
LEFT JOIN 
    supplier_costs sc ON r.total_income > (SELECT AVG(total_income) FROM lineitem_summary)
WHERE 
    o.order_rank <= 10
ORDER BY 
    o.o_totalprice DESC;
