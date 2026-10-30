WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
),
SupplierStats AS (
    SELECT 
        ps.ps_partkey,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_nationkey
),
RecentCustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice
    FROM 
        customer c
    JOIN 
        RankedOrders ro ON c.c_custkey = ro.o_custkey
    JOIN 
        orders o ON ro.o_orderkey = o.o_orderkey
    WHERE 
        ro.rn = 1
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ps.ps_availqty
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
)
SELECT 
    rco.c_name AS CustomerName,
    rco.o_orderkey AS OrderID,
    rco.o_totalprice AS TotalOrderPrice,
    pd.p_name AS PartName,
    pd.p_retailprice AS RetailPrice,
    s.n_nationkey AS SupplierNation,
    ss.total_supplycost AS TotalSupplyCost,
    CASE 
        WHEN rco.o_totalprice > 1000 THEN 'High Value'
        ELSE 'Regular Value' 
    END AS OrderCategory
FROM 
    RecentCustomerOrders rco
JOIN 
    PartDetails pd ON rco.o_orderkey = pd.p_partkey
JOIN 
    SupplierStats ss ON pd.p_partkey = ss.ps_partkey
LEFT JOIN 
    nation s ON ss.s_nationkey = s.n_nationkey
WHERE 
    rco.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
ORDER BY 
    rco.o_totalprice DESC, rco.c_name;
