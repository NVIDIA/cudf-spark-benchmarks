
WITH part_summary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        LENGTH(p.p_comment) AS comment_length,
        (SELECT COUNT(*) FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey) AS supply_count
    FROM 
        part p
    WHERE 
        p.p_retailprice > 50
),
customer_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_nationkey,
        UPPER(c.c_address) AS uppercase_address,
        SUBSTRING(c.c_comment FROM 1 FOR 30) AS truncated_comment,
        LENGTH(c.c_comment) AS customer_comment_length
    FROM 
        customer c
    WHERE 
        c.c_acctbal > 500.00
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        COUNT(l.l_orderkey) AS lineitem_count,
        SUM(l.l_extendedprice) AS total_extended_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus, o.o_totalprice
    HAVING 
        SUM(l.l_extendedprice) > 1000
)
SELECT 
    ps.p_partkey,
    ps.p_name,
    cs.c_custkey,
    cs.c_name,
    os.o_orderkey,
    os.o_orderstatus,
    os.lineitem_count,
    ps.comment_length,
    cs.customer_comment_length
FROM 
    part_summary ps
JOIN 
    customer_summary cs ON cs.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
JOIN 
    order_summary os ON os.o_orderstatus = 'O'
WHERE 
    ps.supply_count > 1
ORDER BY 
    ps.p_name, cs.c_name;
