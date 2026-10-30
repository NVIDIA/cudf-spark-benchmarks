
WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_comment,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey, s.s_comment
),
CustomerTotalSpend AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
Combined AS (
    SELECT 
        sd.s_suppkey,
        sd.s_name,
        sd.s_nationkey,
        ct.c_custkey,
        ct.c_name,
        sd.part_count,
        ct.total_spent,
        CASE 
            WHEN ct.total_spent > 5000 THEN 'High'
            WHEN ct.total_spent BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'Low'
        END AS customer_segment,
        sd.total_available_qty,
        sd.total_supply_cost
    FROM 
        SupplierDetails sd
    JOIN 
        CustomerTotalSpend ct ON sd.s_nationkey = ct.c_custkey
)
SELECT 
    c.c_name AS customer_name,
    s.s_name AS supplier_name,
    c.total_spent,
    s.part_count,
    s.total_available_qty,
    s.total_supply_cost,
    c.customer_segment
FROM 
    Combined c
JOIN 
    SupplierDetails s ON c.s_suppkey = s.s_suppkey
WHERE 
    c.total_spent > 1000
ORDER BY 
    c.total_spent DESC, s.total_supply_cost ASC;
