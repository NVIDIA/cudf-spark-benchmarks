WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS SupplierRank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS TotalOrders,
        SUM(o.o_totalprice) AS TotalSpent,
        SUM(CASE WHEN o.o_orderstatus = 'F' THEN o.o_totalprice ELSE 0 END) AS FinalizedSales
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        RANK() OVER (ORDER BY c.c_acctbal DESC) AS AccountRank
    FROM 
        customer c
    WHERE 
        c.c_acctbal > 5000
)
SELECT 
    r.s_suppkey,
    r.s_name,
    cs.TotalOrders,
    cs.TotalSpent,
    cs.FinalizedSales,
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    COALESCE(hvc.c_name, 'No High Value Customer') AS HighValueCustomer,
    CASE 
        WHEN r.SupplierRank = 1 THEN 'Top Supplier'
        ELSE 'Other Supplier'
    END AS SupplierType
FROM 
    RankedSuppliers r
JOIN 
    part p ON r.s_suppkey = p.p_partkey
LEFT JOIN 
    CustomerOrderSummary cs ON r.s_suppkey = cs.c_custkey
LEFT JOIN 
    HighValueCustomers hvc ON cs.c_custkey = hvc.c_custkey
WHERE 
    r.s_acctbal IS NOT NULL 
    AND p.p_retailprice > 20.00
ORDER BY 
    p.p_partkey, r.s_acctbal DESC;
