
WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_orderdate DESC) AS rnk
    FROM 
        orders AS o
    WHERE 
        o.o_orderdate > '1996-01-01'
),
supplier_parts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ps.ps_partkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        p.p_retailprice
    FROM 
        supplier AS s
    JOIN 
        partsupp AS ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part AS p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice IS NOT NULL AND ps.ps_availqty > 0
),
order_summary AS (
    SELECT 
        lo.l_orderkey,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS revenue,
        COUNT(DISTINCT lo.l_partkey) AS unique_parts
    FROM 
        lineitem AS lo
    GROUP BY 
        lo.l_orderkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    COALESCE(sp.s_name, 'No Supplier') AS supplier_name,
    COALESCE(sp.ps_availqty, 0) AS available_quantity,
    COALESCE(os.revenue, 0) AS total_revenue,
    os.unique_parts,
    CASE 
        WHEN r.o_orderpriority LIKE '%URGENT%' THEN 'High Priority'
        ELSE 'Normal Priority'
    END AS priority_classification
FROM 
    ranked_orders AS r
LEFT JOIN 
    supplier_parts AS sp ON r.o_orderkey = sp.ps_partkey
LEFT JOIN 
    order_summary AS os ON r.o_orderkey = os.l_orderkey
WHERE 
    (r.rnk <= 5 OR sp.ps_supplycost / NULLIF(sp.p_retailprice, 0) < 0.8)
ORDER BY 
    r.o_orderdate DESC, r.o_orderkey;
