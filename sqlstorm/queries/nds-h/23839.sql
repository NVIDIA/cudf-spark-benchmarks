WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
SupplierPartSummary AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available_quantity,
        COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(r.total_available_quantity, 0) AS available_quantity,
    COALESCE(r.unique_suppliers_count, 0) AS suppliers_count,
    COALESCE(s.rank, 0) AS top_supplier_rank,
    c.total_orders,
    c.total_spent,
    CASE 
        WHEN c.avg_order_value IS NULL THEN 'No Orders'
        ELSE 'Orders Exist'
    END AS order_status,
    CASE 
        WHEN s.rank = 1 THEN 'Top Supplier'
        ELSE 'Not Top Supplier'
    END AS supplier_status
FROM 
    part p
LEFT JOIN 
    SupplierPartSummary r ON p.p_partkey = r.ps_partkey
LEFT JOIN 
    RankedSuppliers s ON p.p_partkey = s.s_suppkey
LEFT JOIN 
    CustomerOrders c ON c.total_orders > 0
WHERE 
    p.p_retailprice BETWEEN 10 AND 100
    AND (p.p_comment LIKE '%extra%' OR p.p_comment IS NULL)
ORDER BY 
    p.p_partkey
LIMIT 50;
