WITH SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        p.p_comment,
        ps.ps_availqty,
        ps.ps_supplycost,
        CONCAT(s.s_name, ' - ', p.p_name, ' (', p.p_brand, ')') AS SupplierPartInfo,
        LENGTH(p.p_comment) AS CommentLength
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_comment LIKE '%loyal%'
),
AggregatedData AS (
    SELECT 
        spd.s_suppkey,
        spd.SupplierPartInfo,
        AVG(spd.ps_supplycost) AS AverageSupplyCost,
        SUM(spd.ps_availqty) AS TotalAvailableQuantity,
        AVG(spd.CommentLength) AS AverageCommentLength
    FROM 
        SupplierPartDetails spd
    GROUP BY 
        spd.s_suppkey, spd.SupplierPartInfo
)
SELECT 
    ad.s_suppkey,
    ad.SupplierPartInfo,
    ad.AverageSupplyCost,
    ad.TotalAvailableQuantity,
    ad.AverageCommentLength
FROM 
    AggregatedData ad
ORDER BY 
    ad.AverageSupplyCost DESC, 
    ad.TotalAvailableQuantity ASC;
