WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS SupplierRank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2) 
        AND s.s_acctbal > 1000
),
FilteredItems AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(DISTINCT l.l_orderkey) AS OrderCount,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
        SUM(l.l_quantity) AS TotalQuantity
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        COUNT(DISTINCT l.l_orderkey) > 5
)
SELECT 
    fi.p_partkey,
    fi.p_name,
    fi.OrderCount,
    fi.TotalRevenue,
    fi.TotalQuantity,
    rs.s_name AS TopSupplier
FROM 
    FilteredItems fi
LEFT JOIN 
    RankedSuppliers rs ON fi.p_partkey = rs.s_suppkey
WHERE 
    rs.SupplierRank = 1
ORDER BY 
    fi.TotalRevenue DESC
LIMIT 10;
