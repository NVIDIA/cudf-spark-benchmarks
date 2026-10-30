WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost DESC) as cost_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
HighCostParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COALESCE(SUM(l.l_quantity), 0) AS total_quantity
    FROM 
        part p
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
    HAVING 
        p.p_retailprice > 200.00
),
NationsWithComment AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        n.n_comment,
        CASE 
            WHEN n.n_comment IS NULL THEN 'No Comment' 
            ELSE n.n_comment 
        END AS adjusted_comment
    FROM 
        nation n
    WHERE 
        n.n_name LIKE 'A%' 
)
SELECT 
    c.c_name,
    r.r_name,
    ns.adjusted_comment,
    hpp.p_name,
    hpp.total_quantity,
    ss.s_name AS supplier_name,
    ss.cost_rank
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    HighCostParts hpp ON l.l_partkey = hpp.p_partkey
LEFT JOIN 
    RankedSuppliers ss ON hpp.p_partkey = ss.s_suppkey
JOIN 
    nationsWithComment ns ON c.c_nationkey = ns.n_nationkey
JOIN 
    region r ON ns.n_nationkey = r.r_regionkey
WHERE 
    o.o_orderstatus IN ('O', 'F') 
    AND (hpp.total_quantity > (SELECT AVG(total_quantity) FROM HighCostParts) OR hpp.p_retailprice IS NULL)
ORDER BY 
    hpp.total_quantity DESC NULLS LAST, 
    c.c_name ASC;
