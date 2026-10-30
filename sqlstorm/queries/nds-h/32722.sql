WITH  TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        RANK() OVER (ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(l.l_quantity) AS total_quantity,
        COUNT(DISTINCT o.o_custkey) AS customer_count,
        AVG(o.o_totalprice) OVER (PARTITION BY o.o_orderstatus) AS avg_order_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderstatus
),
HighValueOrders AS (
    SELECT 
        os.o_orderkey, 
        os.o_totalprice,
        os.total_quantity,
        os.customer_count
    FROM 
        OrderSummary os
    WHERE 
        os.o_totalprice > (SELECT AVG(o_totalprice) FROM OrderSummary)
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    ps.ps_partkey,
    COUNT(DISTINCT s.s_suppkey) AS num_suppliers,
    COALESCE(ROUND(AVG(sp.avg_supply_cost), 2), 0) AS avg_cost,
    COALESCE(MAX(hv.total_quantity), 0) AS max_order_quantity,
    COALESCE(SUM(hv.customer_count), 0) AS total_customers
FROM 
    SupplierParts sp
LEFT JOIN 
    partsupp ps ON sp.ps_partkey = ps.ps_partkey
LEFT JOIN 
    TopSuppliers s ON ps.ps_suppkey = s.s_suppkey AND s.rnk <= 10
LEFT JOIN 
    HighValueOrders hv ON hv.o_orderkey = ps.ps_partkey
WHERE 
    sp.total_available > 50 
GROUP BY 
    ps.ps_partkey
ORDER BY 
    ps.ps_partkey DESC;
