
WITH RecursivePart AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        CASE 
            WHEN p.p_size IS NULL THEN 'Unknown Size'
            ELSE CAST(p.p_size AS VARCHAR(255))
        END AS size_text,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS num_parts,
        SUM(ps.ps_supplycost) AS total_cost,
        MAX(ps.ps_availqty) AS max_avail_qty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
BestSuppliers AS (
    SELECT 
        si.s_suppkey,
        si.s_name,
        si.num_parts
    FROM 
        SupplierInfo si
    WHERE 
        si.num_parts >= (
            SELECT AVG(num_parts) FROM SupplierInfo
        )
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_retailprice,
    rp.size_text,
    s.s_name AS supplier_name,
    r.r_name AS region_name,
    CASE 
        WHEN o.o_orderstatus = 'F' THEN 'Fully Processed'
        ELSE 'Pending'
    END AS order_status,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue
FROM 
    RecursivePart rp
LEFT JOIN 
    lineitem li ON rp.p_partkey = li.l_partkey
LEFT JOIN 
    orders o ON li.l_orderkey = o.o_orderkey
LEFT JOIN 
    supplier s ON li.l_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    (rp.price_rank = 1 OR rp.size_text LIKE 'M%')
    AND (o.o_orderdate > '1997-01-01' OR o.o_orderdate IS NULL)
    AND (s.s_acctbal > 1000 OR s.s_acctbal IS NULL)
    AND s.s_suppkey IN (SELECT s_suppkey FROM BestSuppliers)
GROUP BY 
    rp.p_partkey, 
    rp.p_name, 
    rp.p_retailprice, 
    rp.size_text, 
    s.s_name, 
    r.r_name, 
    o.o_orderstatus
ORDER BY 
    total_revenue DESC,
    rp.p_retailprice ASC
LIMIT 50;
