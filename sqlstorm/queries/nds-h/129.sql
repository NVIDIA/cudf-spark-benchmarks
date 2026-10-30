WITH CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), 
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        SUM(ps.ps_availqty) AS total_available_qty
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_partkey) AS parts_supplied
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    co.c_name,
    co.total_spent,
    co.order_count,
    pd.p_name,
    pd.avg_supply_cost,
    si.s_name AS supplier_name,
    CASE 
        WHEN co.total_spent > 10000 THEN 'High Value'
        WHEN co.total_spent BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value,
    ROW_NUMBER() OVER (PARTITION BY CASE 
                                         WHEN co.total_spent > 10000 THEN 'High Value'
                                         WHEN co.total_spent BETWEEN 5000 AND 10000 THEN 'Medium Value'
                                         ELSE 'Low Value'
                                     END ORDER BY co.total_spent DESC) AS rank_within_value_category
FROM 
    CustomerOrders co
JOIN 
    lineitem l ON co.c_custkey = l.l_orderkey
JOIN 
    PartDetails pd ON l.l_partkey = pd.p_partkey
LEFT JOIN 
    SupplierInfo si ON l.l_suppkey = si.s_suppkey
WHERE 
    l.l_shipdate >= '1997-01-01' 
    AND l.l_discount > 0.10
ORDER BY 
    customer_value, co.total_spent DESC;