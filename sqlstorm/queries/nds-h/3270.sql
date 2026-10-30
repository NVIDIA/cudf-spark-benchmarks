WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_total
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    sd.s_suppkey,
    sd.s_name,
    co.c_custkey,
    co.c_name,
    COALESCE(sd.total_cost, 0) AS total_supplier_cost,
    COALESCE(co.order_count, 0) AS customer_order_count,
    COALESCE(co.avg_order_total, 0) AS customer_avg_order_total,
    CASE 
        WHEN co.order_count > 10 THEN 'High Value Customer'
        ELSE 'Standard Customer'
    END AS customer_type,
    ROW_NUMBER() OVER (PARTITION BY co.c_custkey ORDER BY sd.total_cost DESC) AS rank
FROM 
    SupplierDetails sd
FULL OUTER JOIN 
    CustomerOrders co ON sd.s_suppkey = co.c_custkey
WHERE 
    (sd.total_cost > 50000 OR co.avg_order_total > 1000)
ORDER BY 
    customer_order_count DESC,
    total_supplier_cost DESC;
