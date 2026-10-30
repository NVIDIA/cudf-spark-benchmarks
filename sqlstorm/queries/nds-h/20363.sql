
WITH  CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus IN ('O', 'F')   
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost) > 5000.00
),
PartDetail AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        CASE 
            WHEN p.p_size IS NULL THEN 'Unknown Size' 
            ELSE CONCAT(p.p_size, ' units') 
        END AS SizeInfo,
        ROW_NUMBER() OVER (ORDER BY p.p_partkey) AS UniquePartIdx
    FROM 
        part p
)
SELECT 
    co.c_name AS CustomerName,
    COUNT(DISTINCT co.o_orderkey) AS TotalOrders,
    SUM(CASE WHEN li.l_returnflag = 'R' THEN li.l_extendedprice * (1 - li.l_discount) ELSE 0 END) AS TotalReturnedValue,
    AVG(pd.p_retailprice) AS AvgPartRetailPrice,
    STRING_AGG(DISTINCT hs.s_name, ', ') AS HighValueSuppliers
FROM 
    CustomerOrders co
LEFT JOIN 
    lineitem li ON co.o_orderkey = li.l_orderkey
LEFT JOIN 
    PartDetail pd ON li.l_partkey = pd.p_partkey
LEFT JOIN 
    HighValueSuppliers hs ON li.l_suppkey = hs.s_suppkey
WHERE 
    co.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    co.c_name
HAVING 
    COUNT(DISTINCT co.o_orderkey) > 10 OR AVG(pd.p_retailprice) IS NULL
ORDER BY 
    TotalOrders DESC, AvgPartRetailPrice ASC
LIMIT 100;
