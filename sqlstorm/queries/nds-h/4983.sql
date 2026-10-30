WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal
), 
CustomerOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        o.o_totalprice, 
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM 
        orders o
), 
LineItemAnalysis AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS NetSales,
        SUM(l.l_quantity) AS TotalQuantity
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    COALESCE(n.n_name, 'Unknown') AS Nation,
    COUNT(DISTINCT c.c_custkey) AS TotalCustomers,
    SUM(COALESCE(ld.NetSales, 0)) AS TotalNetSales,
    SUM(sup.TotalSupplyCost) AS TotalSupplierCost
FROM 
    nation n
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    CustomerOrders co ON c.c_custkey = co.o_custkey AND co.OrderRank = 1
LEFT JOIN 
    LineItemAnalysis ld ON co.o_orderkey = ld.l_orderkey
LEFT JOIN 
    SupplierDetails sup ON sup.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (
            SELECT p.p_partkey 
            FROM part p 
            WHERE p.p_brand = 'Brand#45'
        )
    )
GROUP BY 
    n.n_name
ORDER BY 
    TotalNetSales DESC, 
    TotalCustomers ASC
LIMIT 10;
