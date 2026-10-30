WITH ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS brand_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice > 100
), 
customer_order_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 2000
    GROUP BY 
        c.c_custkey, 
        c.c_name
), 
supplier_detail AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_nationkey,
        s.s_phone,
        (SELECT COUNT(*) FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey) AS parts_count
    FROM 
        supplier s 
    WHERE 
        s.s_acctbal > 1500
)
SELECT 
    r.r_name,
    n.n_name,
    cp.c_name,
    SUM(lp.l_extendedprice * (1 - lp.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    COUNT(DISTINCT p.p_partkey) AS total_parts,
    COALESCE(MAX(sp.parts_count), 0) AS total_suppliers
FROM 
    lineitem lp
JOIN 
    orders o ON lp.l_orderkey = o.o_orderkey
JOIN 
    customer_order_summary cp ON o.o_custkey = cp.c_custkey
JOIN 
    supplier_detail sp ON lp.l_suppkey = sp.s_suppkey
JOIN 
    nation n ON sp.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    ranked_parts p ON lp.l_partkey = p.p_partkey
WHERE 
    lp.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    r.r_name, 
    n.n_name, 
    cp.c_name
ORDER BY 
    total_revenue DESC, 
    total_orders DESC;