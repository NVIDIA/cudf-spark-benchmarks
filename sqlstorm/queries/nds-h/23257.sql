WITH  part_supplier AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_suppkey,
        s.s_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER(PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rn
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
), 
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        c.c_custkey, c.c_name
),
high_value_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        total_spent
    FROM 
        customer_orders c
    WHERE 
        total_spent > (SELECT AVG(total_spent) FROM customer_orders)
),
supplier_details AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COALESCE(NULLIF(CONCAT(s.s_name, ' - ', s.s_address), ''), 'Unknown Supplier') AS supplier_info
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)
)
SELECT 
    p.p_partkey,
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
    STRING_AGG(DISTINCT sd.supplier_info, ', ') FILTER (WHERE sd.supplier_info IS NOT NULL) AS supplier_information,
    CASE 
        WHEN EXISTS (SELECT 1 FROM high_value_customers hvc WHERE hvc.c_custkey IN (SELECT o.o_custkey FROM orders o WHERE o.o_orderstatus = 'F')) 
        THEN 'High-Value Customer Present' 
        ELSE 'No High-Value Customer' 
    END AS customer_status,
    ROW_NUMBER() OVER(ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS part_rank
FROM 
    part p
JOIN 
    part_supplier ps ON p.p_partkey = ps.p_partkey
LEFT JOIN 
    supplier_details sd ON ps.ps_suppkey = sd.s_suppkey
GROUP BY 
    p.p_partkey, p.p_name
HAVING 
    SUM(ps.ps_availqty) > 0
ORDER BY 
    total_cost DESC;