
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice > 50.00
),
CustomerOrderInfo AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_mktsegment = 'BUILDING'
    GROUP BY 
        c.c_custkey, c.c_name
),
FinalResults AS (
    SELECT 
        coi.c_name AS customer_name,
        COALESCE(rs.s_name, 'No Suppliers') AS top_supplier,
        rs.s_acctbal AS supplier_balance,
        coi.order_count,
        coi.total_spent,
        coi.last_order_date
    FROM 
        CustomerOrderInfo coi
    LEFT JOIN 
        RankedSuppliers rs ON coi.order_count >= 5 AND rs.supplier_rank = 1
)
SELECT 
    fr.customer_name,
    fr.top_supplier,
    fr.supplier_balance,
    fr.order_count,
    fr.total_spent,
    fr.last_order_date
FROM 
    FinalResults fr
WHERE 
    fr.total_spent > 1000.00
ORDER BY 
    fr.total_spent DESC;
