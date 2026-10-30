WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
),

SupplierParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_suppkey,
        s.s_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        p.p_retailprice,
        (ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        p.p_retailprice > 100.00
),

TopSuppliers AS (
    SELECT 
        s.s_name,
        SUM(sp.total_supply_value) AS total_supply_value
    FROM 
        SupplierParts sp
    JOIN 
        supplier s ON sp.s_suppkey = s.s_suppkey
    GROUP BY 
        s.s_name
    HAVING 
        SUM(sp.total_supply_value) > 100000
),

CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        SUM(CASE WHEN o.o_orderstatus = 'O' THEN o.o_totalprice ELSE 0 END) AS open_orders_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)

SELECT 
    co.c_name,
    co.order_count,
    co.total_spent,
    co.open_orders_value,
    ts.total_supply_value AS supplier_influence
FROM 
    CustomerOrders co
LEFT JOIN 
    TopSuppliers ts ON ts.s_name IN (
        SELECT DISTINCT s.s_name
        FROM SupplierParts sp
        JOIN supplier s ON sp.s_suppkey = s.s_suppkey
        JOIN orders o ON o.o_orderkey IN (
            SELECT l.l_orderkey
            FROM lineitem l
            WHERE l.l_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_name LIKE 'Part%')
        )
        WHERE o.o_totalprice > 500
    )
WHERE 
    co.total_spent IS NOT NULL
ORDER BY 
    co.total_spent DESC
LIMIT 10;