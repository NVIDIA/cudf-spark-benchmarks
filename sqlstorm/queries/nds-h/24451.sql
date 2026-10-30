
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),

TopSuppliers AS (
    SELECT 
        * 
    FROM 
        RankedSuppliers 
    WHERE 
        rn <= 3
),

CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),

PartSupplierInfo AS (
    SELECT 
        p.p_partkey,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        MAX(ps.ps_availqty) AS max_avail_qty
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
),

FilteredPartSuppliers AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ps.avg_supply_cost,
        ps.max_avail_qty
    FROM 
        PartSupplierInfo ps
    JOIN 
        part p ON p.p_partkey = ps.p_partkey
    WHERE 
        ps.avg_supply_cost < (SELECT AVG(ps_supplycost) FROM partsupp)
    AND 
        p.p_retailprice > 50.00
)

SELECT 
    co.c_custkey,
    co.total_spent,
    ts.s_name AS supplier_name,
    p.p_name AS part_name,
    p.p_retailprice,
    p.p_brand,
    CASE 
        WHEN l.l_returnflag = 'R' THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status,
    SUM(CASE 
            WHEN l.l_discount > 0.1 THEN l.l_extendedprice * (1 - l.l_discount) 
            ELSE 0 
        END) AS discounted_sales
FROM 
    CustomerOrders co
JOIN 
    orders o ON co.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    FilteredPartSuppliers p ON l.l_partkey = p.p_partkey
LEFT JOIN 
    TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
WHERE 
    co.total_spent IS NOT NULL
AND 
    co.order_count > 0
GROUP BY 
    co.c_custkey, 
    co.total_spent, 
    ts.s_name, 
    p.p_name, 
    p.p_retailprice, 
    p.p_brand, 
    l.l_returnflag
HAVING 
    SUM(l.l_quantity) > 10
ORDER BY 
    co.total_spent DESC, 
    ts.s_name ASC;
