WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_totalprice DESC) as OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
),
TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.o_orderpriority
    FROM 
        RankedOrders ro
    WHERE 
        ro.OrderRank <= 10
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS TotalSpent,
        COUNT(DISTINCT o.o_orderkey) AS NumberOfOrders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    ts.o_orderkey,
    ts.o_orderdate,
    ts.o_totalprice,
    cs.c_name,
    cs.TotalSpent
FROM 
    TopOrders ts
JOIN 
    CustomerSummary cs ON ts.o_orderkey IN (
        SELECT o.o_orderkey 
        FROM orders o 
        WHERE o.o_custkey IN (
            SELECT c.c_custkey 
            FROM customer c
            WHERE c.c_nationkey IN (
                SELECT n.n_nationkey 
                FROM nation n 
                WHERE n.n_regionkey = (
                    SELECT r.r_regionkey 
                    FROM region r 
                    WHERE r.r_name = 'ASIA'
                )
            )
        )
    )
ORDER BY 
    ts.o_orderdate DESC, 
    ts.o_totalprice DESC;