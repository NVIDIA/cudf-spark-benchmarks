WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1995-01-01' AND o.o_orderdate < '1996-01-01'
),
total_quantity_per_part AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        l.l_partkey
),
high_demand_parts AS (
    SELECT 
        pp.p_partkey,
        pp.p_name,
        pp.p_retailprice,
        tq.total_quantity
    FROM 
        part pp
    JOIN 
        total_quantity_per_part tq ON pp.p_partkey = tq.l_partkey
    WHERE 
        tq.total_quantity > 100
),
supplier_details AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        s.s_acctbal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    h.p_name,
    h.p_retailprice,
    s.s_name AS supplier_name,
    s.nation_name,
    r.order_rank,
    CASE 
        WHEN r.o_orderstatus = 'F' THEN 'Finalized'
        ELSE 'Pending'
    END AS order_status_label
FROM 
    ranked_orders r
LEFT JOIN 
    lineitem l ON r.o_orderkey = l.l_orderkey
JOIN 
    high_demand_parts h ON l.l_partkey = h.p_partkey
JOIN 
    supplier_details s ON l.l_suppkey = s.s_suppkey
WHERE 
    r.o_totalprice > 500
    AND (s.nation_name IS NOT NULL OR s.nation_name IS NULL)
ORDER BY 
    r.o_orderdate DESC, r.o_totalprice DESC;