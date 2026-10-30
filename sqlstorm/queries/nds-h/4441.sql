WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS RankInNation
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
), ExpensiveParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        p.p_brand,
        p.p_comment,
        CASE 
            WHEN p.p_retailprice > 1000 THEN 'Expensive'
            ELSE 'Affordable'
        END AS PriceCategory
    FROM 
        part p
    WHERE 
        p.p_size IN (10, 20, 30)
)

SELECT 
    r.r_name AS Region,
    ns.n_name AS Nation,
    COALESCE(RS.s_name, 'No Supplier') AS SupplierName,
    EP.p_name AS PartName,
    EP.PriceCategory,
    EP.p_retailprice,
    SUM(l.l_quantity) AS TotalQuantity,
    SUM(l.l_extendedprice) AS TotalSales,
    CASE 
        WHEN SUM(l.l_discount) > 0.15 THEN 'High Discount'
        ELSE 'Regular Discount'
    END AS DiscountCategory
FROM 
    lineitem l
LEFT OUTER JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT OUTER JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation ns ON c.c_nationkey = ns.n_nationkey
JOIN 
    region r ON ns.n_regionkey = r.r_regionkey
JOIN 
    RankedSuppliers RS ON RS.RankInNation = 1 AND RS.s_suppkey = l.l_suppkey
JOIN 
    ExpensiveParts EP ON l.l_partkey = EP.p_partkey
WHERE 
    l.l_shipdate >= '1997-01-01' AND
    l.l_shipdate < '1997-12-31' AND
    (o.o_orderstatus = 'F' OR o.o_orderstatus = 'P')
GROUP BY 
    r.r_name, ns.n_name, RS.s_name, EP.p_name, EP.PriceCategory, EP.p_retailprice
ORDER BY 
    r.r_name, TotalSales DESC;