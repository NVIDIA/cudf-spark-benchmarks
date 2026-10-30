WITH supplier_details AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS supplier_nation,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
),
top_suppliers AS (
    SELECT 
        sd.s_suppkey,
        sd.s_name,
        ROW_NUMBER() OVER (ORDER BY sd.total_supply_value DESC) AS rank
    FROM 
        supplier_details sd
),
customer_order_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        c.c_acctbal,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS customer_rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
)
SELECT 
    tos.s_suppkey,
    tos.s_name,
    cus.c_custkey,
    cus.c_name,
    cus.order_count,
    cus.total_spent,
    CASE 
        WHEN cus.total_spent IS NULL THEN 'No Orders' 
        ELSE 'Active Customer' 
    END AS customer_status,
    sd.total_supply_value
FROM 
    top_suppliers tos
LEFT JOIN 
    customer_order_summary cus ON tos.s_suppkey = cus.c_custkey
JOIN 
    supplier_details sd ON tos.s_suppkey = sd.s_suppkey
WHERE 
    (cus.total_spent > 1000 OR cus.total_spent IS NULL)
ORDER BY 
    sd.total_supply_value DESC, 
    cus.total_spent ASC
LIMIT 100;
