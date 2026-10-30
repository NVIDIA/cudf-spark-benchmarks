
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS OrderRanking
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1995-01-01'
), 
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
        COUNT(DISTINCT ps.ps_partkey) AS PartCount
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
        COUNT(DISTINCT o.o_orderkey) AS OrderCount,
        SUM(o.o_totalprice) AS TotalSpend
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey 
    GROUP BY 
        c.c_custkey, c.c_name
), 
FilteredOrders AS (
    SELECT 
        RANK() OVER (ORDER BY ro.o_totalprice DESC) AS TotalOrderRank,
        co.c_custkey,
        co.c_name,
        ro.o_totalprice
    FROM 
        RankedOrders ro
    JOIN 
        CustomerOrders co ON ro.o_orderkey = co.OrderCount
    WHERE 
        ro.o_orderstatus IN ('F', 'O')
)

SELECT 
    f.TotalOrderRank,
    f.c_name,
    COALESCE(sd.TotalCost, 0) AS SupplierCost,
    CASE 
        WHEN f.o_totalprice IS NULL THEN 'no orders'
        ELSE CASE 
            WHEN f.o_totalprice < 1000 THEN 'low spender'
            WHEN f.o_totalprice BETWEEN 1000 AND 5000 THEN 'medium spender'
            ELSE 'high spender'
        END 
    END AS SpendingCategory
FROM 
    FilteredOrders f
LEFT JOIN 
    SupplierDetails sd ON f.c_custkey = (
        SELECT MIN(c.c_custkey) 
        FROM customer c 
        WHERE c.c_nationkey = (
            SELECT n.n_nationkey 
            FROM nation n 
            WHERE n.n_name = 'FRANCE'
        )
    )
ORDER BY 
    f.TotalOrderRank DESC, f.c_name ASC;
