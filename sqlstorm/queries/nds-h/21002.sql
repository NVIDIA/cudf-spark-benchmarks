WITH RankedSuppliers AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(l.l_discount) AS total_discount,
        SUM(l.l_extendedprice) AS total_extended_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey, o.o_totalprice
    HAVING 
        AVG(l.l_quantity) > 10.0
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS num_suppliers,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
    HAVING 
        COUNT(DISTINCT ps.ps_suppkey) > 3
),
FinalResult AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(SUM(ho.o_totalprice), 0) AS total_order_value,
        COALESCE(SUM(CASE WHEN rs.rn = 1 THEN rs.s_acctbal END), 0) AS highest_supplier_balance
    FROM 
        part p
    LEFT JOIN 
        HighValueOrders ho ON p.p_partkey = ho.o_orderkey
    LEFT JOIN 
        RankedSuppliers rs ON rs.ps_partkey = p.p_partkey
    JOIN 
        FilteredParts fp ON fp.p_partkey = p.p_partkey
    WHERE 
        NOT EXISTS (
            SELECT 1 
            FROM supplier s 
            WHERE s.s_nationkey IN (
                SELECT n.n_nationkey 
                FROM nation n 
                WHERE n.n_name LIKE 'A%'
            ) AND s.s_acctbal IS NULL
        )
    GROUP BY 
        p.p_partkey, p.p_name
    ORDER BY 
        highest_supplier_balance DESC, total_order_value DESC
)
SELECT 
    DISTINCT f.p_partkey,
    f.p_name,
    f.total_order_value,
    CASE 
        WHEN f.highest_supplier_balance IS NULL THEN 'No Supplier'
        ELSE CONCAT('Balance: ', f.highest_supplier_balance)
    END AS supplier_balance_status
FROM 
    FinalResult f
WHERE 
    f.total_order_value > (SELECT AVG(total_order_value) FROM FinalResult)
ORDER BY 
    f.total_order_value DESC
LIMIT 10;
