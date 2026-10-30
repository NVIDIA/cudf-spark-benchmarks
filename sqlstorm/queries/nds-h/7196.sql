WITH supplier_parts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        ps.ps_availqty,
        ps.ps_supplycost,
        (ps.ps_availqty * ps.ps_supplycost) AS total_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
ranked_parts AS (
    SELECT 
        *,
        DENSE_RANK() OVER (PARTITION BY s_suppkey ORDER BY total_value DESC) AS rank
    FROM 
        supplier_parts
),
top_parts AS (
    SELECT 
        s_suppkey,
        s_name,
        p_partkey,
        p_name,
        p_brand,
        p_type,
        ps_availqty,
        ps_supplycost
    FROM 
        ranked_parts
    WHERE 
        rank <= 5
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        o.o_clerk,
        o.o_shippriority
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'F' AND o.o_orderdate >= cast('1998-10-01' as date) - INTERVAL '1 year'
)
SELECT 
    co.c_custkey,
    co.c_name,
    co.o_orderkey,
    co.o_totalprice,
    tp.p_partkey,
    tp.p_name,
    tp.p_brand,
    tp.p_type,
    tp.ps_availqty,
    tp.ps_supplycost,
    (co.o_totalprice * tp.ps_supplycost) AS order_value
FROM 
    customer_orders co
JOIN 
    top_parts tp ON tp.s_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA'))
ORDER BY 
    order_value DESC, co.o_totalprice DESC;