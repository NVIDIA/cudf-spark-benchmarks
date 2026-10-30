WITH supplier_part_info AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        (ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > 10000
), high_value_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(sp.total_value) AS aggregate_value
    FROM 
        supplier_part_info sp
    JOIN 
        part p ON sp.p_partkey = p.p_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(sp.total_value) > 500000
), order_summary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        o.o_orderdate,
        o.o_orderstatus
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus IN ('F', 'O')
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
), final_report AS (
    SELECT 
        h.p_partkey,
        h.p_name,
        os.total_revenue,
        os.o_orderdate,
        os.o_orderstatus
    FROM 
        high_value_parts h
    LEFT JOIN 
        order_summary os ON h.p_partkey = os.o_orderkey
)
SELECT 
    f.p_partkey,
    f.p_name,
    COALESCE(f.total_revenue, 0) AS total_revenue,
    f.o_orderdate,
    f.o_orderstatus
FROM 
    final_report f
ORDER BY 
    f.total_revenue DESC;
