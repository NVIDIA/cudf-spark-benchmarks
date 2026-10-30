WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O' AND
        o.o_orderdate >= DATE '1997-01-01'
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS SupplierCount,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM 
        partsupp ps 
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    r.r_name,
    np.n_name,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS Revenue,
    (SELECT AVG(TotalSpent) FROM TopCustomers) AS AvgCustomerSpend
FROM 
    lineitem li
JOIN 
    orders o ON li.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    supplier s ON li.l_suppkey = s.s_suppkey
JOIN 
    nation np ON s.s_nationkey = np.n_nationkey
JOIN 
    region r ON np.n_regionkey = r.r_regionkey
LEFT JOIN 
    SupplierParts sp ON li.l_partkey = sp.ps_partkey
WHERE 
    li.l_shipdate >= DATE '1997-01-01' AND 
    (li.l_discount BETWEEN 0.05 AND 0.15 OR li.l_returnflag IS NULL)
GROUP BY 
    r.r_name, np.n_name
HAVING 
    SUM(li.l_extendedprice * (1 - li.l_discount)) > 100000
ORDER BY 
    Revenue DESC;