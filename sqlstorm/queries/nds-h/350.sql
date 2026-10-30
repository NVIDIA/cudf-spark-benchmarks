WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplyrank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_orders,
        COUNT(o.o_orderkey) AS order_count,
        COUNT(DISTINCT l.l_orderkey) AS distinct_orderlines,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
),
ExcessiveSpending AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        co.total_orders,
        CASE 
            WHEN co.total_orders > 10000 THEN 'EXCEEDS'
            ELSE 'WITHIN'
        END AS status
    FROM 
        CustomerOrders co
    JOIN 
        customer c ON co.c_custkey = c.c_custkey
    WHERE 
        co.total_orders IS NOT NULL
),
HighValueSuppliers AS (
    SELECT 
        ss.s_suppkey, 
        ss.s_name,
        ss.total_supplycost,
        ss.unique_parts
    FROM 
        SupplierStats ss
    WHERE 
        ss.supplyrank <= 10
),
FinalReport AS (
    SELECT 
        es.c_custkey,
        es.c_name,
        es.status,
        hvs.s_suppkey,
        hvs.s_name AS supplier_name,
        hvs.total_supplycost,
        hvs.unique_parts
    FROM 
        ExcessiveSpending es
    CROSS JOIN 
        HighValueSuppliers hvs
)
SELECT 
    fr.c_custkey,
    fr.c_name,
    fr.status,
    fr.s_suppkey,
    fr.supplier_name,
    fr.total_supplycost,
    fr.unique_parts
FROM 
    FinalReport fr
WHERE 
    fr.status = 'EXCEEDS'
ORDER BY 
    fr.total_supplycost DESC, 
    fr.c_name ASC;
