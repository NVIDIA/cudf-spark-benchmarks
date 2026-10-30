
WITH SupplierCost AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY
        ps.ps_partkey, ps.ps_suppkey
),
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
),
TopSuppliers AS (
    SELECT 
        sc.ps_partkey,
        sc.ps_suppkey,
        ROW_NUMBER() OVER (PARTITION BY sc.ps_partkey ORDER BY sc.total_supply_cost DESC) AS rn
    FROM 
        SupplierCost sc
)
SELECT 
    p.p_name,
    s.s_name,
    cd.total_spent,
    cd.order_count,
    sc.total_supply_cost
FROM 
    part p
LEFT JOIN 
    TopSuppliers t ON p.p_partkey = t.ps_partkey AND t.rn = 1
LEFT JOIN 
    supplier s ON t.ps_suppkey = s.s_suppkey
LEFT JOIN 
    CustomerOrderDetails cd ON s.s_nationkey = cd.c_custkey
LEFT JOIN 
    SupplierCost sc ON t.ps_partkey = sc.ps_partkey AND t.ps_suppkey = sc.ps_suppkey
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2) 
    AND s.s_acctbal IS NOT NULL
ORDER BY 
    cd.total_spent DESC
LIMIT 10;
