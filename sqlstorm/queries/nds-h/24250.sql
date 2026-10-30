
WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p 
    WHERE 
        p.p_size IN (SELECT DISTINCT ps.ps_availqty 
                      FROM partsupp ps 
                      WHERE ps.ps_supplycost > 0)
), HighValueSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        RANK() OVER (ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL 
        AND s.s_acctbal BETWEEN 1000 AND 5000
), OrderShipDates AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        COUNT(l.l_orderkey) AS line_count,
        MAX(l.l_shipdate) AS latest_ship
    FROM 
        orders o 
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey 
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), CombinedData AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        CASE 
            WHEN hvs.rnk IS NULL THEN 'No Supplier'
            ELSE hvs.s_name 
        END AS supplier_name,
        od.line_count,
        od.latest_ship
    FROM 
        RankedParts rp
    LEFT JOIN 
        HighValueSuppliers hvs ON rp.p_partkey = hvs.s_suppkey
    FULL OUTER JOIN 
        OrderShipDates od ON rp.p_partkey = od.o_orderkey
)

SELECT 
    cd.p_partkey,
    cd.p_name,
    cd.supplier_name,
    COALESCE(cd.line_count, 0) AS total_lines,
    COALESCE(cd.latest_ship, DATE '1900-01-01') AS last_shipping_date,
    CASE 
        WHEN COALESCE(cd.line_count, 0) > 0 THEN 'Active Order'
        ELSE 'No Active Order'
    END AS order_status
FROM 
    CombinedData cd
WHERE 
    cd.supplier_name NOT LIKE 'Unused%'
    OR cd.supplier_name IS NULL
ORDER BY 
    cd.p_partkey;
