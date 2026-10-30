WITH ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_retailprice,
        DENSE_RANK() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice BETWEEN 100 AND 10000
),
supplier_availability AS (
    SELECT 
        ps.ps_partkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail,
        SUM(ps.ps_supplycost) AS total_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_name
),
filtered_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        CASE 
            WHEN o.o_orderstatus = 'F' THEN 'Fully Shipped'
            ELSE 'Pending'
        END AS order_status,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_sequence
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= cast('1998-10-01' as date) - INTERVAL '1 year'
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_mfgr,
    sa.s_name,
    sa.total_avail,
    sa.total_cost,
    fo.o_orderkey,
    fo.order_status
FROM 
    ranked_parts rp
LEFT JOIN 
    supplier_availability sa ON rp.p_partkey = sa.ps_partkey
FULL OUTER JOIN 
    filtered_orders fo ON sa.total_avail IS NULL OR sa.total_avail > 0 
WHERE 
    (rp.price_rank <= 5 OR rp.p_name LIKE 'A%')
    AND (sa.total_cost IS NULL OR sa.total_cost > 1000)
    AND (fo.order_sequence <= 10 OR fo.o_orderkey IS NULL)
ORDER BY 
    rp.p_partkey, sa.s_name, fo.o_orderdate DESC
LIMIT 100;