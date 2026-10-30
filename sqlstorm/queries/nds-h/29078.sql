
WITH PartStats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        LENGTH(p.p_comment) AS comment_length,
        SUM(ps.ps_availqty) AS total_available_qty,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice, LENGTH(p.p_comment)
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
FinalBenchmark AS (
    SELECT 
        ps.p_partkey,
        ps.p_name,
        ps.p_retailprice,
        ps.comment_length,
        ps.total_available_qty,
        ps.supplier_count,
        co.c_custkey,
        co.c_name,
        co.total_order_value,
        co.order_count,
        CONCAT('Part: ', ps.p_name, ' | Customer: ', co.c_name) AS combined_info
    FROM 
        PartStats ps
    JOIN 
        CustomerOrders co ON ps.supplier_count > 0
    ORDER BY 
        ps.total_available_qty DESC, co.total_order_value DESC
)
SELECT 
    *
FROM 
    FinalBenchmark
WHERE 
    LENGTH(combined_info) > 50
LIMIT 100;
