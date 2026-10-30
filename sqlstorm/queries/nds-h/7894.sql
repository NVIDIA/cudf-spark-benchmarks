WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'F'
),
TopOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.o_totalprice,
        r.c_name,
        r.c_acctbal
    FROM 
        RankedOrders r
    WHERE 
        r.OrderRank <= 5
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        COUNT(DISTINCT l.l_orderkey) AS lineitem_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    INNER JOIN 
        TopOrders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    t.o_orderkey,
    t.o_orderdate,
    t.c_name,
    t.c_acctbal,
    os.lineitem_count,
    os.total_revenue
FROM 
    TopOrders t
JOIN 
    OrderSummary os ON t.o_orderkey = os.o_orderkey
ORDER BY 
    os.total_revenue DESC;
