WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        n.n_name AS nation, 
        r.r_name AS region, 
        s.s_acctbal, 
        LENGTH(s.s_comment) AS comment_length
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
PartDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_type, 
        p.p_size, 
        p.p_retailprice, 
        LENGTH(p.p_comment) AS comment_length
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p_retailprice) FROM part)
),
SupplierPartStats AS (
    SELECT 
        s.s_name AS supplier_name, 
        COUNT(DISTINCT ps.ps_partkey) AS supplied_parts, 
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    JOIN 
        SupplierDetails s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        s.s_name
)
SELECT 
    s.supplier_name, 
    s.supplied_parts, 
    s.avg_supply_cost, 
    p.p_name, 
    p.comment_length AS part_comment_length
FROM 
    SupplierPartStats s
JOIN 
    PartDetails p ON s.supplied_parts > 0 
ORDER BY 
    s.avg_supply_cost DESC, 
    part_comment_length ASC
LIMIT 10;
